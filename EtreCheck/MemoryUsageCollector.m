/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "MemoryUsageCollector.h"
#import "NSMutableAttributedString+Etresoft.h"
#import "ByteCountFormatter.h"
#import "XMLBuilder.h"

// Collect information about memory usage.
@implementation MemoryUsageCollector

// Constructor.
- (id) init
  {
  self = [super initWithName: @"memory"];
  
  if(self)
    {
    return self;
    }
    
  return nil;
  }

// Perform the collection.
- (void) performCollection
  {
  [self
    updateStatus:
      NSLocalizedString(@"Sampling processes for memory", NULL)];

  // Collect the average memory usage usage for all processes (5 times).
  NSDictionary * avgMemory = [self collectAverageMemory];
  
  // Sort the result by average value.
  NSArray * processesMemory = [self sortProcesses: avgMemory by: @"mem"];
  
  // Print the top processes.
  [self printTopProcesses: processesMemory];
  }

// Collect the average CPU usage of all processes.
- (NSDictionary *) collectAverageMemory
  {
  NSMutableDictionary * averageProcesses = [NSMutableDictionary dictionary];
  
  for(NSUInteger i = 0; i < 5; ++i)
    {
    usleep(500000);
    
    NSDictionary * currentProcesses = [self collectProcesses];
    
    for(NSString * command in currentProcesses)
      {
      NSMutableDictionary * currentProcess =
        [currentProcesses objectForKey: command];
      NSMutableDictionary * averageProcess =
        [averageProcesses objectForKey: command];
        
      if(!averageProcess)
        [averageProcesses setObject: currentProcess forKey: command];
        
      else if(currentProcess && averageProcess)
        {
        double totalMemory =
          [[averageProcess objectForKey: @"mem"] doubleValue] * i;
        
        double averageMemory =
          [[averageProcess objectForKey: @"mem"] doubleValue];
        
        averageMemory = (totalMemory + averageMemory) / (double)(i + 1);
        
        [averageProcess
          setObject: [NSNumber numberWithDouble: averageMemory]
          forKey: @"mem"];
        }
      }
    }
  
  return averageProcesses;
  }

// Print top processes by memory.
- (void) printTopProcesses: (NSArray *) processes
  {
  [self.result appendAttributedString: [self buildTitle]];
  
  NSUInteger count = 0;
  
  ByteCountFormatter * formatter = [[ByteCountFormatter alloc] init];

  formatter.k1000 = 1024.0;
  
  for(NSDictionary * process in processes)
    {
    [self printTopProcess: process formatter: formatter];
    
    ++count;
          
    if(count >= 5)
      break;
    }

  [self.result appendCR];
  
  [formatter release];
  }

// Print a top process.
// Return YES if the process could be printed.
- (void) printTopProcess: (NSDictionary *) process
  formatter: (ByteCountFormatter *) formatter
  {
  double value = [[process objectForKey: @"mem"] doubleValue];

  int count = [[process objectForKey: @"count"] intValue];
  
  NSString * countString =
    (count > 1)
      ? [NSString stringWithFormat: @"(%d)", count]
      : @"";

  NSString * memoryString =
    [formatter stringFromByteCount: (unsigned long long)value];
  
  NSString * printString =
    [memoryString
      stringByPaddingToLength: 10 withString: @" " startingAtIndex: 0];

  [self.XML startElement: @"process"];
  
  if(value > 1024 * 1024 * 1024 * 2.0)
    {
    [self.XML addAttribute: @"severity" value: @"warning"];
    [self.XML
      addAttribute: @"severity_explanation" value: @"highmemoryusage"];
    }
    
  [self.XML
    addElement: @"name"
    value: [process objectForKey: @"command"]];
  [self.XML
    addElement: @"memory"
    number: [process objectForKey: @"mem"]];
  [self.XML
    addElement: @"count"
    number: [process objectForKey: @"count"]];
  
  [self.XML endElement: @"process"];

  NSString * output =
    [NSString
      stringWithFormat:
        @"    %@\t%@%@\n",
        printString,
        [process objectForKey: @"command"],
        countString];
    
  if(value > 1024 * 1024 * 1024 * 2.0)
    [self.result
      appendString: output
      attributes:
        [NSDictionary
          dictionaryWithObjectsAndKeys:
            [NSColor redColor], NSForegroundColorAttributeName, nil]];      
  else
    [self.result appendString: output];
  }

@end
